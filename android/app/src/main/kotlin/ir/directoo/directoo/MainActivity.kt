package ir.directoo.directoo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val flavorBilling by lazy { FlavorBilling(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "ir.directoo/store").setMethodCallHandler { call, result ->
            if (call.method == "config") {
                result.success(
                    mapOf(
                        "store" to BuildConfig.STORE,
                        "rsaKey" to BuildConfig.STORE_RSA_KEY,
                    ),
                )
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(messenger, "ir.directoo/billing").setMethodCallHandler(flavorBilling)
    }
}
