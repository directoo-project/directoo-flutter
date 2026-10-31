package ir.directoo.directoo

import android.app.Activity
import android.content.Intent
import android.util.Base64
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
import java.nio.charset.StandardCharsets
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

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
                longArgument(call, "priceRials"),
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

    private fun purchase(sku: String, payload: String, priceRials: Long, result: MethodChannel.Result) {
        val billing = connectedPayment(result) ?: return
        if (priceRials <= 0) {
            BazaarPurchaseActivity.start(activity, billing, sku, payload, null, 0, result)
            return
        }
        val secret = BuildConfig.DYNAMIC_PRICE_SECRET
        if (secret.isBlank()) {
            result.error("PURCHASE_FAILED", "کلید تخفیف پویا در env تنظیم نشده است.", null)
            return
        }
        billing.getInAppSkuDetails(listOf(sku)) {
            getSkuDetailsSucceed { items ->
                activity.runOnUiThread {
                    val item = items.firstOrNull { it.sku == sku }
                    if (item == null) {
                        val debug = if (BuildConfig.DEBUG) " این نصب debug است و امضایش با نسخه پیشخان یکی نیست." else ""
                        result.error(
                            "PURCHASE_FAILED",
                            "کالای $sku در کافه‌بازار پیدا نشد.$debug شناسه کالا و امضای برنامه باید با پیشخان یکی باشد.",
                            null,
                        )
                        return@runOnUiThread
                    }
                    val ceiling = parseRials(item.price)
                    if (ceiling != null && priceRials > ceiling) {
                        result.error(
                            "PURCHASE_FAILED",
                            "مبلغ $priceRials ریال از قیمت ثبت‌شده برای $sku بیشتر است (${item.price}). در پیشخان قیمت کالا را به ریال، برابر سقف شارژ بگذار.",
                            null,
                        )
                        return@runOnUiThread
                    }
                    val token = DynamicPriceToken.sign(
                        secret = secret,
                        packageName = activity.packageName,
                        sku = sku,
                        priceRials = priceRials,
                    )
                    BazaarPurchaseActivity.start(activity, billing, sku, payload, token, priceRials, result)
                }
            }
            getSkuDetailsFailed {
                activity.runOnUiThread {
                    result.error("PURCHASE_FAILED", it.message ?: "جزئیات کالا از کافه‌بازار دریافت نشد.", null)
                }
            }
        }
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
            PurchaseRequest(
                productId = productId,
                payload = payload,
                dynamicPriceToken = dynamicPriceToken?.takeIf { it.isNotEmpty() },
            ),
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
                pending.error("PURCHASE_FAILED", paymentError(it.message), null)
                finish()
            }
            failedToBeginFlow {
                pending.error("PURCHASE_FAILED", paymentError(it.message ?: "شروع خرید ناموفق بود."), null)
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
        private var dynamicPriceToken: String? = null
        private var priceRials: Long = 0

        fun start(
            activity: Activity,
            billing: Payment,
            sku: String,
            developerPayload: String,
            priceToken: String?,
            rials: Long,
            pending: MethodChannel.Result,
        ) {
            payment = billing
            result = pending
            productId = sku
            payload = developerPayload
            dynamicPriceToken = priceToken
            priceRials = rials
            activity.startActivity(Intent(activity, BazaarPurchaseActivity::class.java))
        }

        fun paymentError(message: String?): String {
            val detail = message?.takeIf { it.isNotBlank() } ?: "خرید کافه‌بازار ناموفق بود."
            if (priceRials <= 0) return detail
            return "$detail (sku=$productId, price=$priceRials ریال)"
        }
    }
}

private fun longArgument(call: MethodCall, key: String): Long = when (val raw = call.argument<Any>(key)) {
    is Int -> raw.toLong()
    is Long -> raw
    is Number -> raw.toLong()
    else -> 0L
}

private object DynamicPriceToken {
    fun sign(secret: String, packageName: String, sku: String, priceRials: Long): String {
        val header = base64Url("""{"alg":"HS256","typ":"JWT"}""")
        val exp = System.currentTimeMillis() / 1000 + 15 * 60
        val body = base64Url(
            """{"price":$priceRials,"package_name":"${jsonString(packageName)}","sku":"${jsonString(sku)}","exp":$exp,"nonce":"${UUID.randomUUID()}"}""",
        )
        val data = "$header.$body"
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(secret.toByteArray(StandardCharsets.UTF_8), "HmacSHA256"))
        val signature = base64Url(mac.doFinal(data.toByteArray(StandardCharsets.UTF_8)))
        return "$data.$signature"
    }

    private fun jsonString(value: String): String = value.replace("\\", "\\\\").replace("\"", "\\\"")

    private fun base64Url(value: String): String = base64Url(value.toByteArray(StandardCharsets.UTF_8))

    private fun base64Url(value: ByteArray): String =
        Base64.encodeToString(value, Base64.NO_WRAP or Base64.NO_PADDING)
            .replace('+', '-')
            .replace('/', '_')
}

private fun parseRials(price: String): Long? {
    val digits = buildString {
        for (ch in price) {
            when (ch) {
                in '0'..'9' -> append(ch)
                in '۰'..'۹' -> append('0' + (ch - '۰'))
                in '٠'..'٩' -> append('0' + (ch - '٠'))
            }
        }
    }
    return digits.toLongOrNull()
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
